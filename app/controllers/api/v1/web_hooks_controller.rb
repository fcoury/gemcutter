class Api::V1::WebHooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  before_filter :authenticate_with_api_key
  before_filter :verify_authenticated_user
  before_filter :find_gem_by_name, :except => :index

  def index
    render :json => current_user.all_hooks
  end

  def create
    webhook = current_user.web_hooks.build(:url => @url, :rubygem => @rubygem)

    if webhook.save
      render :text   => webhook.success_message,
             :status => :created
    else
      render :text   => webhook.errors.full_messages,
             :status => :conflict
    end
  end

  def remove
    webhook = current_user.web_hooks.find_by_rubygem_id_and_url(
              @rubygem.try(:id),
              @url)

    if webhook.try(:destroy)
      render :text => webhook.removed_message
    else
      render :text   => "No such webhook exists under your account.",
             :status => :not_found
    end
  end

  def fire
    webhook = current_user.web_hooks.new(:url => @url)
    @rubygem = Rubygem.find_by_name("gemcutter") unless @rubygem

    if webhook.fire(request.host_with_port,
                    @rubygem,
                    @rubygem.versions.latest,
                    false)
      render :text => webhook.deployed_message
    else
      render :text => webhook.failed_message, :status => :bad_request
    end
  end

  protected

  def find_gem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)

    if @rubygem.nil? && @gem_name != WebHook::GLOBAL_PATTERN
      render :text   => "This gem could not be found",
             :status => :not_found
    end
  end
end
