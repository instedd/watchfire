class UserMailer < Devise::Mailer
  add_template_helper MailerHelper
  layout 'mail'

  default from: Watchfire::Application.config.from_email

  def invite_to_organization(inviter, organization, email, token)
    @organization = organization
    @email = email
    @token = token
    mail({
      to: email,
      subject: "#{inviter.display_name} invited you to join Watchfire in the #{organization.name} organization",
    })
  end
end