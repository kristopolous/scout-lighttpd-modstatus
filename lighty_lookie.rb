$VERBOSE = false

class LightyLookie < Scout::Plugin
  needs 'net/http'
  needs 'rubygems'
  needs 'yaml'

  OPTIONS=<<-EOS
  url_status:
    name: Status URL to monitor
    notes: This is the mod_status status.status-url with ?auto appended at the end, by you, the typist.
    default: http://127.0.0.1/server-status?auto
  url_statistics:
    name: Statistics URL to monitor
    notes: This is the mod_status status.statistics-url with ?auto appended at the end, by you, the typist.
    default: http://127.0.0.1/server-statistics?auto
  credential_user:
    name: HTTP User
    notes: The HTTP user, if needed, via mod_auth
  credential_password:
    name: HTTP Password
    notes: The HTTP password, if needed, via mod_auth
  EOS

  def build_report
    counterList = ["Total Accesses", "Total kBytes"]
    rejectList = ["Scoreboard"]

    begin
      credentialMap = {
        :user => option("credential_user").to_s.strip,
        :password => option("credential_password").to_s.strip
      }

      myReport = {}
      myCounters = []
      myTotal = {}
      ["url_status", "url_statistics"].each { | which | 
        begin
          uri_unparsed = option(which).to_s.strip
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
          return error( "URL error", "Ruby says: #{e.message}<br><br>#{e.backtrace.join('<br>')}" )
        end

        begin
          likely_yaml = YAML::load(payload)
        rescue
          return error("Couldn't convert #{payload} to YAML")
        end

        if likely_yaml.class == Hash
          myTotal.merge!(likely_yaml)
          myCounters += likely_yaml.select { | key, value | counterList.index(key) }

          myReport.merge!(likely_yaml.reject { | key, value | 
            rejectList.index(key) || counterList.index(key) || (key =~ /^fastcgi/ && !(key =~ /^fastcgi.backend.([0-9].){1,2}load$/ ))
          })
        else
          return error("Payload wasn't yaml. We can't parse #{payload}. Ah shucks'")
        end
      }

      bucketMap = {}
      myTotal.select { | key, value | myReport.keys.index(key).nil? and key =~ /^fastcgi.backend/ }.each { | key, value |
        parts = key.split(/\./)
        # dump fastcgi.backend
        parts.shift(2)
        bucket = parts.pop

        bucketMap[bucket] = {
          :cardinality => 0,
          :sum => 0
        } unless bucketMap.has_key? bucket

        bucketMap[bucket][:cardinality] += 1
        bucketMap[bucket][:sum] += value
      }

      bucketMap.each { | key, map |
        myReport["#{key} sum"] = map[:sum]
      }

      myCounters.uniq.each { | row |
        key, value = row
        counter(key, value, :per => :minute)
      }

      report(myReport)

    rescue Exception => e
      error( "Uncaught exception occured.",
             "Ruby says: #{e.message}<br><br>#{e.backtrace.join('<br>')}" )
    end
  end
end
