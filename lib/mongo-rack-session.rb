require 'rack/session/abstract/id'
require 'mongo_mapper'
require 'uuid'
require 'active_support' # probably already included from mongo_mapper

module Rack
  module Session
    class Mongo < Abstract::ID
      VERSION = '0.1.1'
      class Session
        include MongoMapper::Document

        key "Id", String
        key :Expired, Boolean
        key :HostAddress, String
        key :LastAccessTime, Time
        key :StartTimestamp, Time
        key :StopTimestamp, Time
        key :Timeout, Integer
        key :Attributes, Hash

        def is_valid?
          if self.Timeout && self.StartTimestamp 
            (self.StartTimestamp + (self.Timeout/1000).seconds > Time.now) ? self : nil
          else
            nil
          end
        end

        def key?(k)
          self if self.class.key?(k) # || @Attributes.key?(k)
        end

        def sort_by(*args, &block)
          flat_obj = send(:Attributes)
          tmp_obj = {}
          self.keys.each do |k,v|
            unless k == "Attributes"
              tmp_obj[k] = send(k.to_sym)
            end
          end
          flat_obj.update tmp_obj

          block.call(flat_obj)
        end

        def []=(k,val)
          if k == 'flash'
          elsif self.class.key?(k)
            send("#{k}=".to_sym, val)
          else
            self.Attributes[k] = val
          end
        end
        def [](k)
          if k == 'flash'
            @flash ||= ActionDispatch::Flash::FlashHash.new
          elsif self.class.key?(k)
            send(k.to_sym)
          else
            @Attributes[k]
          end
        end
        
      end

      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge \
        :mongo_db_name => 'shiro',
        :mongo_collection_name => 'Sessions',
        :mongo_server => 'mongohost',
        :default_key => 'JSESSIONID',  # cookie key
        :session_class_key => 'Id'

      def initialize(app, options={})
        super
        @key = options[:key] || @default_options[:default_key]

        # set up the Session Class either defined by the User or using the one defined above
        @@session_class = options[:session_class] || Session
        @@session_class.set_database_name(options[:mongo_db_name] || @default_options[:mongo_db_name])
        @@session_class.set_collection_name(options[:mongo_collection_name] || @default_options[:mongo_collection_name])
        @@session_class.connection(::Mongo::Connection.new(options[:mongo_server] || @default_options[:mongo_server]))
        @@session_class_key = options[:session_class_key] || @default_options[:session_class_key]
      end

      def get_session(env, sid)
        sid ||= generate_sid
        session = find_session(env, sid)
        [sid, session]
      end

      def set_session(env, session_id, new_session, options)
        session = find_session(env, session_id)
        (session && new_session && session.Id == new_session.Id && new_session.save) ? new_session.Id : nil
      end

      def find_session(env, sid)
        mongo_session = @@session_class.first(:conditions => {@@session_class_key => sid})

        unless mongo_session.try(:is_valid?)
          timestamp = Time.now
          mongo_session = @@session_class.create(
            :Id => sid,
            :Expired => false,
            :HostAddress => env['action_dispatch.remote_ip'].to_s,
            :LastAccessTime => timestamp,
            :StartTimestamp => timestamp,
            :Timeout => 2592000000,
            :Attributes => {"org.apache.shiro.subject.support.DefaultSubjectContext_AUTHENTICATED_SESSION_KEY" => false})
        end

        mongo_session
      end

      def generate_sid
        UUID.generate
      end
    end
  end
end

