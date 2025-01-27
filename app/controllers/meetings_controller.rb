class MeetingsController < ApplicationController
  def create
    service = ZoomMeetingService.new
    meeting_url = service.create_meeting
    render json: { meeting_url: meeting_url }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
