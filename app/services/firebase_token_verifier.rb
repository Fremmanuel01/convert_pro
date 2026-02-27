require 'jwt'
require 'httparty'

class FirebaseTokenVerifier
  CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

  def self.verify(token)
    project_id = ENV.fetch('FIREBASE_PROJECT_ID')
    
    # 1. Decode the token header to find out which Google public key was used to sign it
    # We pass false because we haven't verified it yet
    begin
      _, header = JWT.decode(token, nil, false)
      kid = header['kid']
    rescue JWT::DecodeError => e
      Rails.logger.error "Firebase Token Decode Error: #{e.message}"
      return nil
    end

    # 2. Fetch Google's public x509 certificates and cache them for 1 hour
    # This automatically uses SolidCache (PostgreSQL) instead of requiring Redis!
    certificates = Rails.cache.fetch('firebase_certificates', expires_in: 1.hour) do
      response = HTTParty.get(CERT_URL)
      
      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error "Failed to fetch Firebase certificates: #{response.code}"
        {}
      end
    end

    # If the certificate used to sign the token isn't in Google's list, it's invalid
    return nil unless certificates[kid]

    # 3. Cryptographically verify the token signature using the correct certificate
    begin
      cert = OpenSSL::X509::Certificate.new(certificates[kid])
      public_key = cert.public_key

      decoded_token = JWT.decode(token, public_key, true, {
        algorithm: 'RS256',
        verify_aud: true, aud: project_id,
        verify_iss: true, iss: "https://securetoken.google.com/#{project_id}"
      })
      
      # Return the verified payload
      decoded_token.first
    rescue JWT::DecodeError => e
      Rails.logger.error "Firebase JWT Signature Verification Error: #{e.message}"
      nil
    end
  end
end
