class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ edit update destroy ]

  def index
    @contacts = Contact.alphabetical
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      redirect_to contacts_path, notice: "Contato salvo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "Contato atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy!
    redirect_to contacts_path, notice: "Contato apagado.", status: :see_other
  end

  private
    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.expect(contact: %i[ name company linkedin_url kind last_contacted_on notes ])
    end
end
