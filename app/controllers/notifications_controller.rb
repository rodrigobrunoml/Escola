class NotificationsController < ApplicationController
  before_action :set_notification, only: [:show, :edit, :update, :destroy]
  before_action :verify_login, except: [:index, :check]
  protect_from_forgery except: [:check]

  # GET /notifications
  # GET /notifications.json
  def index
    parent = params[:parent_id]
    last_update = params[:last_update]

    if parent && last_update
      @notifications = Notification.where("parent_id = ? and updated_at > ?", parent, last_update);
    else
      @notifications = Notification.all
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
  end

  # GET /notifications/new
  def new
    @notification = Notification.new
    @student_classes = StudentClass.all
  end

  # GET /notifications/1/edit
  def edit
  end

  def check
    ids = eval(params[:ids])

    ids.each do |id|
      puts "id = #{id}"
      notification = Notification.find(id)
      notification.status = 2
      notification.save
    end

    render json: {status: :ok}
  end

  # POST /notifications
  # POST /notifications.json
  def create
    @notification = Notification.new(notification_params)

    class_student = @notification.student_class
    no_error = true
    registration_ids = [];

    class_student.student.each do |student|
      student.student_parents.each do |sp|
        parent = sp.parent

        if parent.registration_id
          notif = @notification
          notif.parent_id = parent.id
          notif.student_id = student.id
          notif.status = 0
          registration_ids << parent.registration_id

          no_error = notif.save
        end
      end
    end

    gcm = GCM.new("AIzaSyAoWGH5o7yE78YImhr4ji60reTvCtpmMxQ")
    registration_ids= registration_ids
    options = {data: {title: @notification.title, message: @notification.message}, collapse_key: "updated_score"}
    @response = gcm.send(registration_ids, options)

    respond_to do |format|
       if no_error
         format.html { redirect_to notifications_path, notice: 'Notification was successfully created.' }
        format.json { render :show, status: :created, location: @notification }
      else
        format.html { render :new }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notifications/1
  # PATCH/PUT /notifications/1.json
  def update
    respond_to do |format|
      if @notification.update(notification_params)
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { render :show, status: :ok, location: @notification }
      else
        format.html { render :edit }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to notifications_url, notice: 'Notification was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification
      @notification = Notification.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def notification_params
      params.require(:notification).permit(:student_class_id, :studant_id, :title, :message)
    end
end
