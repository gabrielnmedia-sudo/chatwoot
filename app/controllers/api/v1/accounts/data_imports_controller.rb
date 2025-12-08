class Api::V1::Accounts::DataImportsController < Api::V1::Accounts::BaseController
  def index
    @data_imports = Current.account.data_imports.order(created_at: :desc).page(params[:page])
  end

  def show
    @data_import = Current.account.data_imports.find(params[:id])
  end
end
