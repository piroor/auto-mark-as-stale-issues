require 'octokit'

repo = ENV["GITHUB_REPOSITORY"]
label_to_be_added = ENV["LABEL"] || "stale"
candidate_labels = (ENV["CANDIDATE_LABELS"] || "").split(",").collect{|label| label.strip }
exception_labels = (ENV["EXCEPTION_LABELS"] || "").split(",").collect{|label| label.strip }
expire_days = ENV["EXPIRE_DAYS"] || 0
extend_days_by_commented = ENV["EXTEND_DAYS_BY_COMMENTED"] || expire_days
comment = ENV["COMMENT"] || "This issue has been labeled as \"#{label_to_be_added}\" due to no response by the reporter within #{expire_days} days (and #{extend_days_by_commented} days after last commented by someone)."

client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
client.auto_paginate = true

labels = candidate_labels.join(",")
p "Finding issues with one of #{labels}"
open_issues = client.list_issues(repo, { :labels => labels, :state => "open" })
p " => #{open_issues.size} issues found"

now = Time.new.to_i
expire_days_in_seconds = expire_days.to_i * 60 * 60 * 24
extend_days_by_commented_in_seconds = extend_days_by_commented.to_i * 60 * 60 * 24

p "Checking issues with expire days #{expire_days} and exception labels #{exception_labels.join(", ")}"
open_issues.each do |issue|
  p "Issue #{issue.number} (#{issue.labels.collect{|label| label.name }.join(", ")})"
  if issue.labels.any?{|label| label.name == label_to_be_added }
    p " => already marked"
    next
  end
  if not exception_labels.empty? and issue.labels.any?{|label| exception_labels.any?(label.name) }
    p " => has one of exceptions #{exception_labels.join(", ")}"
    next
  end
  timeline = client.issue_timeline(repo, issue.number)

  reporter_id = issue.user.id
  reporter_last_commented_event = timeline.select{|event| event.event == "commented" and event.user.id == reporter_id }.last
  if reporter_last_commented_event and now - reporter_last_commented_event.created_at.to_i <= expire_days_in_seconds
    p " => not stale yet (from reporter's last comment)"
    next
  end

  if now - issue.created_at.to_i <= expire_days_in_seconds
    p " => not stale yet (from reported)"
    next
  end

  last_commented_event = timeline.select{|event| event.event == "commented" and event.user.type != "Bot" }.last
  if last_commented_event and now - last_commented_event.created_at.to_i <= extend_days_by_commented_in_seconds
    p " => not stale yet (from last commented by someone)"
    next
  end

  p " => stale"
  client.add_labels_to_an_issue(repo, issue.number, [label_to_be_added])
  client.add_comment(repo, issue.number, comment)
end
