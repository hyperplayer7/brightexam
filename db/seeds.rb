# db/seeds.rb

def seed_user!(email:, role:, password: "password")
  user = User.find_or_initialize_by(email: email)
  user.role = role

  # Only set password on first create (so deploys don't keep changing it)
  if user.new_record?
    user.password = password
    user.password_confirmation = password
  end

  user.save!
end

seed_user!(email: "employee@test.com", role: :employee)
seed_user!(email: "employee2@test.com", role: :employee)
seed_user!(email: "employee3@test.com", role: :employee)

seed_user!(email: "reviewer@test.com", role: :reviewer)
seed_user!(email: "reviewer2@test.com", role: :reviewer)

%w[Transport Meals Supplies].each do |name|
  Category.find_or_create_by!(name: name)
end
