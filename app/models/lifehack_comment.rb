class LifehackComment < ApplicationRecord
  belongs_to :user
  belongs_to :lifehack

  validates :comment, presence: true

  # 通知機能
  has_many :notifications, dependent: :destroy
  # コメントが投稿された際に通知を作成するメソッド
  def create_notification_comment!(current_user, comment_id)
    # 自分以外にコメントしている人をすべて取得し、全員に通知を送る
    other_commenters_ids = LifehackComment.select(:user_id).where(lifehack_id:).where.not(user_id: current_user.id).distinct.pluck(:user_id)

    # 各コメントユーザーに対して通知を作成
    other_commenters_ids.each do |commenter_id|
      save_notification_comment!(current_user, comment_id, commenter_id)
    end

    # まだ誰もコメントしていない場合は、投稿者に通知を送る
    save_notification_comment!(current_user, comment_id, user_id) if other_commenters_ids.blank?
  end

  # 通知を保存するメソッド
  def save_notification_comment!(current_user, comment_id, visited_id)
    notification = current_user.active_notifications.build(
      lifehack_id: id,
      comment_id:,
      visited_id:,
      action: 'comment'
    )

    # 自分の投稿に対するコメントの場合は、通知済みとする
    notification.is_checked = true if notification.visitor_id == notification.visited_id

    # 通知を保存（バリデーションが成功する場合のみ）
    notification.save if notification.valid?
  end
end
