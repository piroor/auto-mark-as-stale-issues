require 'octokit'

repo = ENV["GITHUB_REPOSITORY"]
label_to_be_added = ENV["LABEL"] || "stale"
candidate_labels = (ENV["CANDIDATE_LABELS"] || "").split(",").collect{|label| label.strip }
expire_days = ENV["EXPIRE_DAYS"] || 0
comment = ENV["COMMENT"] || "This issue has been labeled as \"#{label_to_be_added}\" due to no response in #{expire_days} days."

client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
client.auto_paginate = true

labels = candidate_labels.join(",")
p "Finding issues with one of #{labels}"
open_issues = client.list_issues(repo, { :labels => labels, :state => "open" })
p " => #{open_issues.size} issues found"

now = Time.new.to_i
expire_days_in_seconds = expire_days.to_i * 60 * 60 * 24

p "Checking issues with expire days #{expire_days}"
open_issues.each do |issue|
  p "Issue #{issue.number} (#{issue.labels.collect{|label| label.name }.join(", ")})"
  if issue.labels.any?{|label| label.name == label_to_be_added }
    p " => already marked"
    next
  end
  past_seconds = now - issue.updated_at.to_i
  if past_seconds > expire_days_in_seconds
    p " => stale"
    client.add_labels_to_an_issue(repo, issue.number, [label_to_be_added])
    client.add_comment(repo, issue.number, comment)
  else
    p " => not stale yet"
  end
end
