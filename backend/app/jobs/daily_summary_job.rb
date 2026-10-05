class DailySummaryJob < ApplicationJob
  queue_as :default

  def perform
    Standups::BuildDailySummaries.call
  end
end
