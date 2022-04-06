class Administration::CertificatesController < ApiController
  before_action { authenticate(allow_plain: true) }

  before_action(only: :create) { head :conflict if UpvsEnvironment.subject?(params[:id]) }
  before_action(only: [:show, :destroy]) { head :not_found unless UpvsEnvironment.subject?(params[:id]) }

  def create
    UpvsEnvironment.create_subject(params[:id], **params.permit(:cin).to_options)

    head :created
  end

  def show
    subject = UpvsEnvironment.subject(params[:id])

    render json: subject
  end

  def destroy
    UpvsEnvironment.delete_subject(params[:id])

    head :no_content
  end
end
