class SwaggerController < ApplicationController
  skip_before_action :set_current_user
  skip_around_action :switch_locale
  skip_around_action :handle_with_exception

  after_action :remove_mini_profiler_scripts

  def respond
    file_path = Rails.root.join('swagger', derived_path)
    content = file_path.read

    # Set appropriate content type based on file extension
    content_type = if derived_path.end_with?('.html')
                     'text/html'
                   elsif derived_path.end_with?('.json')
                     'application/json'
                   elsif derived_path.end_with?('.yml', '.yaml')
                     'text/yaml'
                   else
                     'text/plain'
                   end

    render inline: content, content_type: content_type
  end

  private

  def remove_mini_profiler_scripts
    return unless response.content_type&.include?('text/html')
    return unless response.body.present?

    # Remove mini-profiler script tags from the HTML
    response.body = response.body.gsub(%r{<script[^>]*mini-profiler[^>]*></script>}i, '')
  end

  def derived_path
    params[:path] ||= 'index.html'
    path = Rack::Utils.clean_path_info(params[:path])
    path << ".#{Rack::Utils.clean_path_info(params[:format])}" unless path.ends_with?(params[:format].to_s)
    path
  end
end
