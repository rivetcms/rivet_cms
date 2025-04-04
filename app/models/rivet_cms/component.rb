module RivetCms
  class Component < ApplicationRecord
    has_prefix_id :comp, minimum_length: RivetCms.configuration.prefixed_ids_length, salt: RivetCms.configuration.prefixed_ids_salt, alphabet: RivetCms.configuration.prefixed_ids_alphabet
  end
end
