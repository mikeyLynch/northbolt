PUBLIC_IMPORTMAP = Importmap::Map.new.tap do |map|
  map.draw(Rails.root.join("config/importmaps/public.rb"))
end
