require "rails_helper"

RSpec.describe "Webhooks::Stora", type: :request do
  let(:business) { create(:business, stora_webhook_token: "test-token-abc", stora_webhook_secret: "test-secret") }
  let(:location) { create(:location, business: business) }
  let(:lock)     { create(:lock, location: location, unit_identifier: "A1") }

  before { lock }

  def sign(body, secret: "test-secret", timestamp: Time.now.to_i)
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
    [ "t=#{timestamp},v1=#{sig}", timestamp ]
  end

  def post_webhook(payload, signature_header)
    post "/webhooks/stora/test-token-abc",
         params: payload.to_json,
         headers: {
           "Content-Type"      => "application/json",
           "X-Stora-Signature" => signature_header
         }
  end

  # ── Security ──────────────────────────────────────────────────────────────────

  describe "security" do
    let(:payload) { { event: { type: "subscription.ended" }, subscription: { unit_id: "A1", tenant_id: "t-1" } } }

    it "returns 404 for an unknown token" do
      sig, = sign(payload.to_json)
      post "/webhooks/stora/unknown-token",
           params: payload.to_json,
           headers: { "Content-Type" => "application/json", "X-Stora-Signature" => sig }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 for a missing signature" do
      post "/webhooks/stora/test-token-abc",
           params: payload.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a wrong secret" do
      sig, = sign(payload.to_json, secret: "wrong-secret")
      post_webhook(payload, sig)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a timestamp older than 5 minutes" do
      old_timestamp = 6.minutes.ago.to_i
      sig, = sign(payload.to_json, timestamp: old_timestamp)
      post_webhook(payload, sig)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 400 for malformed JSON" do
      sig, = sign("not-json")
      post "/webhooks/stora/test-token-abc",
           params: "not-json",
           headers: { "Content-Type" => "application/json", "X-Stora-Signature" => sig }
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 200 for an unhandled event type" do
      body = { event: { type: "unit.created" } }
      sig, = sign(body.to_json)
      post_webhook(body, sig)
      expect(response).to have_http_status(:ok)
    end
  end

  # ── subscription.started ──────────────────────────────────────────────────────

  describe "subscription.started" do
    let(:payload) do
      {
        event:        { type: "subscription.started", id: SecureRandom.uuid },
        subscription: { id: SecureRandom.uuid, unit_id: "A1", tenant_id: "stora-t-1",
                        starts_at: "2026-06-01T09:00:00Z", ends_at: "2026-09-01T09:00:00Z" },
        tenant:       { id: "stora-t-1", first_name: "Alice", last_name: "Brown", email: "alice@example.com" }
      }
    end

    it "returns 200" do
      sig, = sign(payload.to_json)
      post_webhook(payload, sig)
      expect(response).to have_http_status(:ok)
    end

    it "creates a new tenant" do
      sig, = sign(payload.to_json)
      expect { post_webhook(payload, sig) }.to change { business.tenants.count }.by(1)

      tenant = business.tenants.find_by(external_id: "stora-t-1")
      expect(tenant.first_name).to eq("Alice")
      expect(tenant.last_name).to eq("Brown")
      expect(tenant.email).to eq("alice@example.com")
    end

    it "creates an access grant on the correct lock" do
      sig, = sign(payload.to_json)
      expect { post_webhook(payload, sig) }.to change { lock.access_grants.count }.by(1)

      grant = lock.access_grants.last
      expect(grant.starts_at).to be_within(1.second).of(Time.zone.parse("2026-06-01T09:00:00Z"))
      expect(grant.ends_at).to be_within(1.second).of(Time.zone.parse("2026-09-01T09:00:00Z"))
      expect(grant.revoked_at).to be_nil
    end

    it "queues a PIN email to the tenant" do
      sig, = sign(payload.to_json)
      expect { post_webhook(payload, sig) }.to have_enqueued_mail(TenantMailer, :access_granted)
    end

    it "finds an existing tenant by external_id rather than creating a duplicate" do
      create(:tenant, business: business, external_id: "stora-t-1", email: "alice@example.com")
      sig, = sign(payload.to_json)
      expect { post_webhook(payload, sig) }.not_to change { business.tenants.count }
    end

    it "does nothing if the unit identifier does not match any lock" do
      body = payload.merge(subscription: payload[:subscription].merge(unit_id: "UNKNOWN"))
      sig, = sign(body.to_json)
      expect { post_webhook(body, sig) }.not_to change { AccessGrant.count }
      expect(response).to have_http_status(:ok)
    end
  end

  # ── subscription.cancelled / subscription.ended ───────────────────────────────

  %w[subscription.cancelled subscription.ended].each do |event_type|
    describe event_type do
      let(:tenant) { create(:tenant, business: business, external_id: "stora-t-2") }
      let!(:grant) { create(:access_grant, lock: lock, tenant: tenant) }

      let(:payload) do
        {
          event:        { type: event_type, id: SecureRandom.uuid },
          subscription: { id: SecureRandom.uuid, unit_id: "A1", tenant_id: "stora-t-2",
                          starts_at: nil, ends_at: nil },
          tenant:       { id: "stora-t-2" }
        }
      end

      it "returns 200" do
        sig, = sign(payload.to_json)
        post_webhook(payload, sig)
        expect(response).to have_http_status(:ok)
      end

      it "revokes the active grant" do
        sig, = sign(payload.to_json)
        post_webhook(payload, sig)
        expect(grant.reload.revoked_at).not_to be_nil
      end

      it "does not affect grants belonging to other tenants on the same lock" do
        other_tenant = create(:tenant, business: business)
        other_grant  = create(:access_grant, :revoked, lock: lock, tenant: other_tenant)
        sig, = sign(payload.to_json)
        post_webhook(payload, sig)
        expect(other_grant.reload.revoked_at).to eq(other_grant.revoked_at)
      end
    end
  end

  # ── invoice.marked_uncollectible ─────────────────────────────────────────────

  describe "invoice.marked_uncollectible" do
    let(:tenant)    { create(:tenant, business: business, external_id: "stora-t-3") }
    let(:lock2)     { create(:lock, location: location, unit_identifier: "A2") }
    let!(:grant1)   { create(:access_grant, lock: lock,  tenant: tenant) }
    let!(:grant2)   { create(:access_grant, lock: lock2, tenant: tenant) }

    let(:payload) do
      {
        event:   { type: "invoice.marked_uncollectible", id: SecureRandom.uuid },
        invoice: { id: SecureRandom.uuid, tenant_id: "stora-t-3" },
        tenant:  { id: "stora-t-3" }
      }
    end

    it "returns 200" do
      sig, = sign(payload.to_json)
      post_webhook(payload, sig)
      expect(response).to have_http_status(:ok)
    end

    it "revokes all active grants for the tenant across all locks" do
      sig, = sign(payload.to_json)
      post_webhook(payload, sig)
      expect(grant1.reload.revoked_at).not_to be_nil
      expect(grant2.reload.revoked_at).not_to be_nil
    end

    it "returns 200 and does nothing if the tenant is unknown" do
      body = payload.merge(invoice: { id: SecureRandom.uuid, tenant_id: "no-such-tenant" })
      sig, = sign(body.to_json)
      expect { post_webhook(body, sig) }.not_to change { AccessGrant.where(revoked_at: nil).count }
      expect(response).to have_http_status(:ok)
    end
  end
end
