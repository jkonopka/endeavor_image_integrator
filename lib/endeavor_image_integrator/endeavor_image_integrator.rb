module EndeavorImageIntegrator
  class Worker
    @running = true
    def self.start(options = {})
      LOGGER.info "Starting EndeavorImageIntegrator Worker with options:#{options.inspect}"
      @pebblebed = ::Pebblebed::Connector.new(GROVEKEY, {})
      @grove = @pebblebed.grove

      @options = parse_options(options)
      @river = Pebblebed::River.new()
      @river.connect
      @q = @river.queue({:name => TOOTSIE_DONE_QUEUE, :event => "tootsie_done"})

      process_event unless options[:all]
      if(options[:all])
        while(@running)
          process_event
        end
      end
    end

    def self.stop
      LOGGER.info "Stopping EndeavorImageIntegrator Worker"
      @running = false
    end

    def self.parse_options(options)
      default_options.merge(options)
    end

    def self.default_options
      {
        :quiet => false,
        :abort_on_503 => false
      }
    end

    def self.process_event
      begin
        @q.pop({:ack => true, :auto_ack => false}) do |delivery_info|
          if delivery_info[:payload] != :queue_empty
            payload = JSON.parse(delivery_info[:payload])
            message = JSON.parse(payload["data"]["message"])
            if message["reference"]
              listing = @grove.get("/posts/post.listing:#{message["reference"]["grovepath"]}", { external_id: "#{message["reference"]["external_id"]}", unpublished: "include"})
              repost = {
                :external_id => listing[:post][:external_id],
                :external_document => listing[:post][:document],
                :tags => listing[:post][:tags].to_a
              }
              repost[:tags] -= ["needs_tootsie"]
              repost[:external_document][:tootsie][:status] = "ok"
              message["outputs"].each { |output| 
                suffix = File.basename(output["url"]).chomp(File.extname(output["url"]))
                repost[:external_document][:tootsie][:primary_photo][suffix] = {
                  :url => output["url"],
                  :width => output["width"],
                  :height => output["height"]
                }
              }
              result = @grove.post("/posts/post.listing:#{message["reference"]["grovepath"]}", {post: repost})
              @q.ack(:delivery_tag => delivery_info[:delivery_details][:delivery_tag])
            end
          end
        end
      rescue Pebblebed::HttpError => e
        LOGGER.warn "Pebblebed::HttpError - listing not updated"
        LOGGER.warn "-------------------------\nstatus: #{e.status}\n(#{JSON.parse(e.response.body)})\n #{e.inspect}\n"
      rescue Curl::Err::ConnectionFailedError => e
        LOGGER.warn "Curl::Err::ConnectionFailedError - listing not updated"
        LOGGER.warn "-------------------------\nerror: #{e.inspect}"
      rescue Curl::Err::HostResolutionError => e
        LOGGER.warn "Curl::Err::ConnectionFailedError - listing not updated"
        LOGGER.warn "-------------------------\nerror: #{e.inspect}"
      end
    end

  end
end