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
        key :StartTimestamp, Time
        key :Timeout, Integer

        def is_valid?
          if self.Timeout && self.StartTimestamp 
            (self.StartTimestamp + (self.Timeout/1000).seconds > Time.now) ? self : nil
          else
            nil
          end
        end
      end

      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge \
        :mongo_db_name => 'shiro',
        :mongo_collection_name => 'Sessions',
        :mongo_server => '10.0.0.82',
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
        session = find_session(sid)
        [sid, session]
      end

      def set_session(env, session_id, new_session, options)
        new_session.save ? new_session.Id : nil
      end

      def find_session(sid)
        mongo_session = @@session_class.first(:conditions => {@@session_class_key => sid})
        (mongo_session && mongo_session.is_valid?) || @@session_class.create(@@session_class_key => sid)
      end

      def generate_sid
        UUID.generate
      end
    end
  end
end
