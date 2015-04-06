require 'net/http'
require 'json'
require 'dotenv'

Dotenv.load

# Pull list of all coworkers
uri = URI('https://spaces.nexudus.com/api/spaces/coworkers?size=1000')
http = Net::HTTP.new(uri.host, uri.port)
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http.use_ssl = true
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth ENV['NEXUDUS_USER'], ENV['NEXUDUS_PASS']
response = http.request(request)
body = response.body
full_hash = JSON.parse(body)
records_hash = full_hash["Records"]

# Pull in existing JSON file

exist_file = File.read(ENV['JSON_FILE'])
exist_hash = JSON.parse(exist_file)

records_hash.each do |account| 
    new_info = nil 
    exist_record = exist_hash.find { |fl| fl["Email"] == account["Email"] }
    account.keys.each do |key|
        if account[key] != exist_record[key] && key != "AccessCardId"
            new_info = 1
        end
    end

    if new_info
        person_uri = URI('https://spaces.nexudus.com/api/spaces/coworkers/' + account["Id"].to_s)
        http = Net::HTTP.new(person_uri.host, person_uri.port)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.use_ssl = true
        request = Net::HTTP::Get.new(person_uri.request_uri)
        request.basic_auth ENV['NEXUDUS_USER'], ENV['NEXUDUS_PASS']
        response = http.request(request)
        body = response.body
        person_hash = JSON.parse(body)
        puts "#{account["FullName"]}, #{account["Email"]} ==> Card: #{person_hash["AccessCardId"]}"
        account["AccessCardId"] = person_hash["AccessCardId"]
        puts "Access Card now: #{account["AccessCardId"]}"
        sleep 2
    else
        puts "No new data for #{account["Email"]}"
    end
end

File.open(ENV['JSON_FILE'], 'w') do |f|
    f.write(JSON.pretty_generate(records_hash))
end


