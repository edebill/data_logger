# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_data_logger_session',
  :secret      => '7992a4f31d46d4ea3143464a1f280733d2a68ef09e2c3790e8238d334f920c88f9af2b0df5bdafcbddd8852ce5517b01b9653c1b515fb8bdac4f85a731c4eb60'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
