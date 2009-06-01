# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_trendingtopics_session',
  :secret      => '8de384d4c2b507409612286579c67c862fcfa45af508d2daa93d2cd78597977e10987c14a50eac96702919baa0e4e7e6d1d38001f176edd49d5e5eabd494a4af'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
