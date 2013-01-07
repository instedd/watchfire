class UserMailer < Devise::Mailer
  add_template_helper MailerHelper
  layout 'mail'

  def invite_to_organization(inviter, organization, email)
    @organization = organization
    @email = email
    mail({
      to: email,
      subject: "#{inviter.display_name} invited you to join Watchfire in the #{organization.name} organization",
    })
  end
end