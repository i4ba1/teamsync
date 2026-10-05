class UserRepository < ApplicationRepository
  class << self
    def find(id)
      User.find(id)
    end

    def active_find(id)
      User.active.find_by(id: id)
    end

    def find_by_email(email)
      return nil if email.blank?

      User.find_by(email: email.downcase)
    end

    def active_by_email(email)
      return nil if email.blank?

      User.active.find_by(email: email.downcase)
    end

    def create(attributes)
      User.create(attributes)
    end

    def update(user, attributes)
      user.update(attributes)
    end
  end
end
