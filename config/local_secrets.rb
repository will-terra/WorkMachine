require "fileutils"
require "securerandom"
require "yaml"

# Secrets of this installation that nobody should have to type: the Active Record Encryption keys
# (keys and passwords saved in Ajustes) and, in production, secret_key_base. They are generated
# on the first boot into storage/ (the Docker volume, next to the database) and read from there
# afterwards. An environment variable with the same name in upper case wins.
module LocalSecrets
  SIZES = {
    "secret_key_base" => 64,
    "active_record_encryption_primary_key" => 32,
    "active_record_encryption_deterministic_key" => 32,
    "active_record_encryption_key_derivation_salt" => 32
  }.freeze

  module_function

  def path
    ENV.fetch("WORKMACHINE_SECRETS_PATH") { File.expand_path("../storage/workmachine-secrets.yml", __dir__) }
  end

  def [](name)
    return "0" * (SIZES.fetch(name.to_s) * 2) if ENV["SECRET_KEY_BASE_DUMMY"].present? # assets:precompile in the image build

    ENV[name.to_s.upcase].presence || values.fetch(name.to_s)
  end

  def values
    @values ||= load_or_create
  end

  def load_or_create
    stored = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
    missing = SIZES.except(*stored.keys)
    return stored if missing.empty?

    stored = stored.merge(missing.to_h { |name, bytes| [ name, SecureRandom.hex(bytes) ] })
    FileUtils.mkdir_p(File.dirname(path))
    temporary = "#{path}.#{Process.pid}.tmp"
    File.write(temporary, stored.to_yaml, perm: 0o600)
    File.rename(temporary, path)
    stored
  end
end
