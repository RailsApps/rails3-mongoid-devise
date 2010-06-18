class User
  include Mongoid::Document

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  field :name, :accessible => false
  field :email, :accessible => false
  field :password, :accessible => false
  field :password_confirmation, :accessible => false
  validates_presence_of :name, :email
  validates_uniqueness_of :name, :email, :case_sensitive => false

end
