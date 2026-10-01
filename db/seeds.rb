# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# db/seeds.rb
if Rails.env.development?
  # Wipe local data to ensure a repeatable seed.
  Like.delete_all
  Comment.delete_all
  Relationship.delete_all
  Post.delete_all
  User.delete_all
  ActiveStorage::Attachment.delete_all
  ActiveStorage::Blob.delete_all

  alice = User.create!(
    email: "alice@example.com",
    username: "alice",
    full_name: "Alice Anderson",
    location: "Portland, OR",
    bio: "Rails developer. Tea enthusiast. Dog person.",
    password: "password123",
    password_confirmation: "password123"
  )

  bob = User.create!(
    email: "bob@example.com",
    username: "bob",
    full_name: "Bob Barker",
    location: "Austin, TX",
    bio: "Car dealer, part-time speaker. Proud dad of two.",
    password: "password123",
    password_confirmation: "password123"
  )

  carol = User.create!(
    email: "carol@example.com",
    username: "carol",
    full_name: "Carol Chen",
    location: "Brooklyn, NY",
    bio: "Rubyist, knitter, and chronic re-reader.",
    password: "password123",
    password_confirmation: "password123"
  )

  dan = User.create!(
    email: "dan@example.com",
    username: "dan",
    full_name: "Dan Rivera",
    location: "San Diego, CA",
    bio: "Surf, tacos, and CI pipelines.",
    password: "password123",
    password_confirmation: "password123"
  )

  # Posts
  p1 = alice.posts.create!(content: "Just shipped the Odinbook feed logic. So satisfying!")
  p2 = bob.posts.create!(content: "If it has four wheels and runs, I'll sell it.")
  p3 = carol.posts.create!(content: "My cat just judged me for writing another migration.")
  p4 = dan.posts.create!(content: "The waves are perfect this morning.")

  # Comments
  p1.comments.create!(user: bob, content: "That feed query looks clean. Nice work!")
  p2.comments.create!(user: carol, content: "Do you throw in floor mats for free?")
  p2.comments.create!(user: dan, content: "Tempting...")
  p3.comments.create!(user: alice, content: "Big same. My cat is filing a formal complaint.")

  # Likes
  [ bob, carol, dan ].each { |u| p1.likes.find_or_create_by!(user: u) }
  [ alice, carol ].each { |u| p2.likes.find_or_create_by!(user: u) }
  [ alice, bob, dan ].each { |u| p3.likes.find_or_create_by!(user: u) }
  [ alice, bob, carol ].each { |u| p4.likes.find_or_create_by!(user: u) }

  # Follow graph (accepted)
  Relationship.find_or_create_by!(follower: alice, following: bob).tap { |r| r.update!(status: Relationship::ACCEPTED) }
  Relationship.find_or_create_by!(follower: alice, following: carol).tap { |r| r.update!(status: Relationship::ACCEPTED) }
  Relationship.find_or_create_by!(follower: bob, following: alice).tap { |r| r.update!(status: Relationship::ACCEPTED) }
  Relationship.find_or_create_by!(follower: carol, following: alice).tap { |r| r.update!(status: Relationship::ACCEPTED) }
  Relationship.find_or_create_by!(follower: carol, following: dan).tap { |r| r.update!(status: Relationship::ACCEPTED) }
  Relationship.find_or_create_by!(follower: dan, following: carol).tap { |r| r.update!(status: Relationship::ACCEPTED) }

  # A pending follow request
  Relationship.find_or_create_by!(follower: dan, following: alice).update!(status: Relationship::PENDING)

  puts "Seeded #{User.count} users, #{Post.count} posts, #{Comment.count} comments, #{Like.count} likes and #{Relationship.count} relationships."
end
