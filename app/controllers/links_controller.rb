class LinksController < ApplicationController

  before_action :set_link, only: [:show]

  # GET /links
  # GET /links.json
  def index
    puts params.inspect.red
    if params[:tag]
      links = current_user.links.tagged_with(params[:tag])
    elsif params[:site]
      links = current_user.links.where(domain: params[:site])
    else
      links = current_user.links
    end
    @links = links.page(params[:page]).order('posted_at DESC')
  end

  # GET /links/1
  # GET /links/1.json
  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_link
    @link = Link.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def link_params
    params.require(:link).permit(:title, :description, :url, :image_url, :content, :domain, :posted_at)
  end
end
