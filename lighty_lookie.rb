$VERBOSE = false

class LightyLookie < Scout::Plugin
  needs 'net/http'
  needs 'rubygems'
  needs 'yaml'

  OPTIONS=<<-EOS
  url:
    name: Url to monitor
    notes: This is the mod_status url, with ?auto appended at the end, by you, the typist. "http://127.0.0.1/server-status?auto" is really common.
    default: http://127.0.0.1/server-status?auto
  credential_user:
    name: HTTP User
    notes: The HTTP user, if needed, via mod_auth
  credential_password:
    name: HTTP Password
    notes: The HTTP password, if needed, via mod_auth
  EOS

  def build_report
    begin
      credentialMap = {
        :user => option("credential_user").to_s.strip,
        :password => option("credential_password").to_s.strip
      }

      begin
        uri_unparsed = option("url").to_s.strip
        uri = URI(uri_unparsed)
        req = Net::HTTP::Get.new(uri.request_uri)

        if credentialMap[:user].length > 0
          req.basic_auth credentialMap[:user], credentialMap[:password]
        end

        res = Net::HTTP.start(uri.host, uri.port) { | http |
          http.request(req)
        }

        payload = res.body
      rescue Exception => e
        return error( "URL error",
             "Ruby says: #{e.message}<br><br>#{e.backtrace.join('<br>')}" )
      end

      begin
        likely_yaml = YAML::load(payload)
      rescue
        return error("Couldn't convert #{payload} to YAML")
      end

      report(likely_yaml)

    rescue Exception => e
      error( "Uncaught exception occured.",
             "Ruby says: #{e.message}<br><br>#{e.backtrace.join('<br>')}" )
    end
  end
end
