settings = [
  {:name => "rest_api_enabled", :value => 1},
  {:name => "app_title", :value => ENV["vg_hostname"]},
  {:name => "host_name", :value => ENV["vg_hostname"]}
  #{:name => "default_language", :value => "en"},
]

for each in settings do
  if !Setting.find_by_name( each[:name] )
    Setting.create( :name => each[:name], :value => each[:value] )
  else
    set = Setting.find_by_name( each[:name] )
    set.value = each[:value]
    set.save!
  end
end
