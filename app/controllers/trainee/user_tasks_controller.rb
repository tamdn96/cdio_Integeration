class Trainee::UserTasksController < ApplicationController
  before_action :logged_in_user
  before_action :load_user_task
  before_action :verify_subject_must_be_active
  after_action :notify_finish_subject
  def update
    verify_clear_task_in_progress @ut
    unless @user_tasks.blank?
      flash[:danger] = "You must finish task in progress before receiver a new task!"
    else
      if @ut.update_attributes(params_user_task)
        case params[:status]
        when "in_progress"
          @ut.update_attributes date_receive: Time.zone.today
          flash[:success] = "You had been receiver task, let do it! Good Luck"
        else
          @ut.update_attributes date_finish: Time.zone.today
        end
      else
        flash[:danger] = "Sorry, this is error"
      end
    end
    redirect_back fallback_location: root_path
  end

  private

  def notify_finish_subject
    user_subject = @ut.user_subject
    if user_subject.user_tasks.finish.size == user_subject.user_tasks.size
      user_subject.update_attributes status: "finish", date_end: Time.zone.today
      ReportProgressMailer.report_subject(user_subject).deliver_now
      flash[:notify_finish_subject] = t "user_tasks.notify_finish_task"
    end
  end

  def load_user_task
    @ut = UserTask.find_by id: params[:id]
    return if @ut
    flash[:danger] = "update unsuccess"
    redirect_back fallback_location: root_path
  end

  def params_user_task
    params.permit :status
  end

  def verify_subject_must_be_active
    unless @ut.user_subject.course.in_progress?
      flash[:danger] = "Sorry, this course must in progress to report task"
      redirect_back fallback_location: root_path
    end
    unless @ut.user_subject.course_subject.in_progress?
      flash[:danger] = "Sorry, this subject must in progress to report task"
      redirect_back fallback_location: root_path
    end
  end

  def verify_clear_task_in_progress ut
    user_subject = UserSubject.find_by id: ut.user_subject_id
    @user_tasks = user_subject.user_tasks.status_in_progress.not_this ut
  end
end
