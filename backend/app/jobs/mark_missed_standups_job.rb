class MarkMissedStandupsJob < ApplicationJob
  queue_as :default

  def perform
    Standups::MarkMissed.call
  end
end
