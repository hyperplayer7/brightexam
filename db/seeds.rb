employee = User.find_or_initialize_by(email: "employee@test.com")
employee.password = "password"
employee.password_confirmation = "password"
employee.role = :employee
employee.save!

reviewer = User.find_or_initialize_by(email: "reviewer@test.com")
reviewer.password = "password"
reviewer.password_confirmation = "password"
reviewer.role = :reviewer
reviewer.save!
