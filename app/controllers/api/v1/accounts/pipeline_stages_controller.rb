class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_pipeline_stage, except: [:index, :create, :reorder]
  before_action :check_authorization

  def index
    @pipeline_stages = Current.account.pipeline_stages
  end

  def create
    @pipeline_stage = Current.account.pipeline_stages.create!(permitted_params)
  end

  def update
    @pipeline_stage.update!(permitted_params)
  end

  def destroy
    @pipeline_stage.destroy!
    head :ok
  end

  def reorder
    params[:ordering].each_with_index do |id, index|
      Current.account.pipeline_stages.find(id).update(position: index + 1)
    end
    head :ok
  end

  private

  def fetch_pipeline_stage
    @pipeline_stage = Current.account.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:name, :color)
  end
end
