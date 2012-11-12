require 'rack/session/abstract/id'
require 'mongo_mapper'
require 'uuid'

module Rack
  module Session
    class Mongo < Abstract::ID
      VERSION = '0.3.0'

      class SessionDocument
        include MongoMapper::Document

        key :Id, String
        key :Expired, Boolean
        key :HostAddress, String
        key :LastAccessTime, Time
        key :StartTimestamp, Time
        key :StopTimestamp, Time
        key :Timeout, Integer
        key :Attributes, Hash

        def is_valid?
          if self[:Timeout] && self[:LastAccessTime]
            (self[:LastAccessTime] + (self[:Timeout] / 1000).seconds > Time.now) ? self : nil
          else
            nil
          end
        end
      end

      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge({
        :mongo_db_name => 'shiro',
        :mongo_collection_name => 'Sessions',
        :mongo_server => 'mongohost',
        :default_key => 'JSESSIONID'})

      def initialize(app, options={})
        super
        @key = options[:key] || @default_options[:default_key]
        SessionDocument.set_database_name(options[:mongo_db_name] || @default_options[:mongo_db_name])
        SessionDocument.set_collection_name(options[:mongo_collection_name] || @default_options[:mongo_collection_name])
        SessionDocument.connection(::Mongo::Connection.new(options[:mongo_server] || @default_options[:mongo_server]))
      end

      def get_session(env, sid)
        document = find_session(env, sid)
        [document[:Id], document[:Attributes]]
      end

      def set_session(env, sid, session, options)
        document = find_session(env, sid)
        document[:Attributes] = session
        document[:LastAccessTime] = Time.now
        document[:Id] if document.save
      end

      def find_session(env, sid)
        document = SessionDocument.first(:conditions => {:Id => sid}) if sid.present?
        timestamp = Time.now

        unless document.try(:is_valid?)
          document = SessionDocument.create(
            :Id => generate_sid,
            :Expired => false,
            :HostAddress => env['action_dispatch.remote_ip'].to_s,
            :LastAccessTime => timestamp,
            :StartTimestamp => timestamp,
            :Timeout => 2592000000,
            :Attributes => {"org.apache.shiro.subject.support.DefaultSubjectContext_AUTHENTICATED_SESSION_KEY" => false})
        end

        document
      end

      def generate_sid
        UUID.generate
      end
    end
  end
end
