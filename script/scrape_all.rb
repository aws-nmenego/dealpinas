require 'yaml'

$config =  YAML.load_file "../config/deal_sites.yml"

if $config['scrape_time'].nil?
  $config['scrape_time'] = Time.now
  YAML.dump $config , open("../config/deal_sites.yml", "w")
else
  system 'ruby','get_ensogo.com.ph.rb'

  system 'ruby','get_clever_buy.com.ph.rb'

  system 'ruby','get_luck_7.rb'

  system 'ruby','get_tcat.com.ph.rb'

  system 'ruby','get_dealspot.ph.rb'

  system 'ruby','get_cashcashpinoy.com.rb'

  system 'ruby','get_dealdozen.com.rb'

  system 'ruby','get_buyanihan.com.rb'

  system 'ruby','get_gupo.com.ph.rb'

  system 'ruby','get_megadeals.ph.rb'

  system 'ruby','get_dealstent.com.rb'

  system 'ruby','get_pinoygreatdeals.com.rb'

  system 'ruby','get_sulitkeni.com.rb'
end


