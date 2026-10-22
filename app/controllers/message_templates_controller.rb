class MessageTemplatesController < ApplicationController
  before_action :set_message_template, only: %i[ edit update destroy ]

  # The "Mensagens" page. Opened from a posting, an application or a contact, it pre-fills the placeholders.
  def index
    @profile = Profile.current
    @message_templates = MessageTemplate.ordered
    @context = context_record
    @values = placeholder_values
    @selected = @message_templates.find { it.id == params[:template_id].to_i } || (MessageTemplate.for_contact(@context) if @context.is_a?(Contact)) || @message_templates.first
    @applications = JobApplication.in_progress.latest_first
  end

  def new
    @message_template = MessageTemplate.new
  end

  def create
    @message_template = MessageTemplate.new(message_template_params)

    if @message_template.save
      redirect_to message_templates_path, notice: "Modelo criado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @message_template.update(message_template_params)
      redirect_to message_templates_path(anchor: helpers.dom_id(@message_template)), notice: "Modelo atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @message_template.destroy!
    redirect_to message_templates_path, notice: "Modelo apagado.", status: :see_other
  end

  private
    def set_message_template
      @message_template = MessageTemplate.find(params[:id])
    end

    def message_template_params
      params.expect(message_template: %i[ name language body max_chars ])
    end

    def context_record
      if params[:job_application_id].present? then JobApplication.find(params[:job_application_id])
      elsif params[:job_posting_id].present? then JobPosting.find(params[:job_posting_id])
      elsif params[:contact_id].present? then Contact.find(params[:contact_id])
      end
    end

    def placeholder_values
      values =
        case @context
        when JobApplication then { "nome" => @context.contact_name, "cargo" => @context.role, "empresa" => @context.company }
        when JobPosting then { "cargo" => @context.title, "empresa" => @context.company }
        when Contact then { "nome" => @context.name, "empresa" => @context.company }
        else {}
        end
      values["nome"] = first_name(values["nome"])
      MessageTemplate::PLACEHOLDERS.index_with { |key| params[key].presence || values[key].to_s }
    end

    def first_name(name)
      name.to_s.split.first
    end
end
