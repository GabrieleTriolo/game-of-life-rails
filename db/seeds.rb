# Crea un utente demo per testing
User.find_or_create_by!(email: 'user@user.it') do |user|
    user.password = 'password'
    user.password_confirmation = 'password'
  end
  
  puts "✅ Utente demo creato: user@user.it / password"