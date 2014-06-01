class User < ActiveRecord::Base
  rolify
  include Authority::UserAbilities

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  has_many :posts, dependent: :destroy

  after_create :set_default_role, if: Proc.new { User.count > 1 }

  def self.find_for_facebook_oauth(auth)
    user = where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.password = "12345678" # 사용자 등록후 비밀번호 변경을 안내해서 반드시 수정하도록 한다.
      # user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name   # assuming the user model has a name
      user.image = auth.info.image # assuming the user model has an image
    end

    # 이 때는 이상하게도 after_create 콜백이 호출되지 않아서 아래와 같은 임시조치를 한다.
    user.add_role :user if user.roles.empty?
    user   # 최종 반환값은 user 객체이어야 한다.
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  private

  def set_default_role
    add_role :user
  end

end
