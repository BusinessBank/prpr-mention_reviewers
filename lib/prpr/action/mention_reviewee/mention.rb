module Prpr
  module Action
    module MentionReviewee
      class Mention < Base
        def call
          if review_state == 'approved'
            Publisher::Adapter::Base.broadcast message
          end
        end

        private

        def message
          channel = to_dm? ? reviewee_mention_name : room
          Prpr::Publisher::Message.new(body: body, from: from, room: channel)
        end

        def pull_request
          event.pull_request
        end

        def pull_request_owner
          pull_request.user
        end

        def review
          event.review
        end

        def review_state
          review.state
        end

        def requested_reviewer
          event.requested_reviewer
        end

        def body
          <<-END
#{reviewee_mention_name}
#{comment_body}
#{pull_request.html_url}
          END
        end

        def comment_body
          comment = env.format(:mention_reviewee_body, pull_request)
          # comment.empty? ? "Please review my PR: #{pull_request.title}" : comment
          comment.empty? ? "`#{pull_request.title}`のレビューを承認しました :+1:" : comment
        end

        def reviewee_mention_name
          members[reviewee] || reviewee
        end

        def reviewee
          "@#{pull_request_owner.login}"
        end

        def from
          event.sender
        end

        def room
          env[:mention_comment_room]
        end

        def members
          @members ||= config.read(name).lines.map { |line|
            if line =~ / \* (\S+):\s*(\S+)/
              [$1, $2]
            end
          }.to_h
        rescue
          @members ||= {}
        end

        def config
          @config ||= Config::Github.new(repository_name)
        end

        def env
          Config::Env.default
        end

        def name
          env[:mention_comment_members] || 'MEMBERS.md'
        end

        def repository_name
          env[:member_repo_name]
        end

        def to_dm?
          env[:mention_reviewers_to_dm] == 'true'
        end
      end
    end
  end
end
