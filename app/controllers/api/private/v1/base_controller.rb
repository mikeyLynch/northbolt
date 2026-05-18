class Api::Private::V1::BaseController < ActionController::API
  before_action :authenticate_lock!

  private

  def authenticate_lock!
    uuid      = request.headers["X-Device-UUID"]
    signature = request.headers["X-Signature"]

    return unauthorized! unless uuid.present? && signature.present?

    @current_lock = Lock.find_by(device_uuid: uuid)
    return unauthorized! unless @current_lock&.public_key.present?

    unauthorized! unless valid_signature?(signature)
  end

  def valid_signature?(signature)
    # Verify the request body was signed with the lock's private key.
    # Uses RbNaCl Curve25519 — the lock signs SHA256(body + timestamp),
    # we verify with the stored public key.
    verify_key = RbNaCl::Signatures::Ed25519::VerifyKey.new(
      Base64.strict_decode64(@current_lock.public_key)
    )
    message = "#{request.raw_post}#{request.headers['X-Timestamp']}"
    verify_key.verify(Base64.strict_decode64(signature), message)
  rescue RbNaCl::BadSignatureError, ArgumentError
    false
  end

  def unauthorized!
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
