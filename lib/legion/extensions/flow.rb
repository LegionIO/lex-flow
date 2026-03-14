# frozen_string_literal: true

require 'legion/extensions/flow/version'
require 'legion/extensions/flow/helpers/constants'
require 'legion/extensions/flow/helpers/flow_detector'
require 'legion/extensions/flow/runners/flow'
require 'legion/extensions/flow/client'

module Legion
  module Extensions
    module Flow
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
