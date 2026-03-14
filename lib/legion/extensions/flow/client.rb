# frozen_string_literal: true

require 'legion/extensions/flow/helpers/constants'
require 'legion/extensions/flow/helpers/flow_detector'
require 'legion/extensions/flow/runners/flow'

module Legion
  module Extensions
    module Flow
      class Client
        include Runners::Flow

        attr_reader :flow_detector

        def initialize(flow_detector: nil, **)
          @flow_detector = flow_detector || Helpers::FlowDetector.new
        end
      end
    end
  end
end
