# frozen_string_literal: true

require 'test_helper'

class ImportJobsControllerTest < ActionController::TestCase
  setup do
    @cas_user = cas_users(:test_admin)
    mock_cas_login(@cas_user.cas_directory_id)
  end

  test 'actions should redirect to login when unauthenticated' do
    mock_cas_logout

    actions = %i[index new create]

    actions.each do |action|
      get action
      assert_redirected_to 'http://test.host/login', "Unauthenticated user not redirected to login for #{action}"
    end
  end

  test 'index page should show all jobs when user is an admin' do
    assert ImportJob.count.positive?, 'Test requires at least one import job'
    assert @cas_user.admin?, 'Test requires an admin user'

    get :index
    import_jobs = assigns(:import_jobs)
    assert_equal ImportJob.count, import_jobs.count
  end

  test "index page should show only user's jobs when user is not an admin" do
    assert ImportJob.count > 1, 'Test requires at least two import jobs'

    @cas_user = cas_users(:test_user)
    mock_cas_login(@cas_user.cas_directory_id)

    # Set up an import job for the user
    import_job = ImportJob.first
    import_job.cas_user = @cas_user
    import_job.save!

    assert @cas_user.user?, 'Test requires a non-admin user'

    get :index
    import_jobs = assigns(:import_jobs)
    assert import_jobs.count.positive?, 'User must have at least one import job.'
    assert import_jobs.count < ImportJob.count, 'There must be some jobs not belonging to user.'
    import_jobs.each do |j|
      assert_equal @cas_user, j.cas_user
    end
  end

  test 'should get new' do
    get :new

    new_import_job = assigns(:import_job)
    assert_not_nil new_import_job

    # Import job name should start with CAS directory id
    assert_match(/^#{@cas_user.cas_directory_id}/, new_import_job.name)
  end

  test 'should create import_job' do
    mock_stomp_client

    name = "#{@cas_user.cas_directory_id}-#{Time.now.iso8601}"
    assert_difference('ImportJob.count') do
      post :create, params: {
        import_job: { name: name, file_to_upload: fixture_file_upload('files/valid_import.csv') }
      }
    end

    assert_redirected_to import_jobs_url
  end

  test 'name is required when creating import_job' do
    name = ''
    assert_no_difference('ImportJob.count') do
      post :create, params: {
        import_job: { name: name, file_to_upload: fixture_file_upload('files/valid_import.csv') }
      }
    end

    # Verify that error message is provided
    import_job = assigns(:import_job)
    assert_includes(import_job.errors.messages[:name],
                    I18n.t('errors.messages.blank'))
  end

  test 'file attachment is required when creating import_job' do
    name = "#{@cas_user.cas_directory_id}-#{Time.now.iso8601}"
    assert_no_difference('ImportJob.count') do
      post :create, params: {
        import_job: { name: name }
      }
    end

    # Verify that error message is provided
    import_job = assigns(:import_job)
    assert_includes(import_job.errors.messages[:file_to_upload],
                    I18n.t('activerecord.errors.models.import_job.attributes.file_to_upload.required'))
  end

  test 'file attachment is required when updating import_job' do
    import_job = ImportJob.first
    patch :update, params: { id: import_job.id, import_job: { name: import_job.name } }
    result = assigns(:import_job)
    assert_includes(result.errors.messages[:file_to_upload],
                    I18n.t('activerecord.errors.models.import_job.attributes.file_to_upload.required'))
    assert_template :edit
  end

  test 'name cannot be blank when updating import_job' do
    import_job = ImportJob.first
    patch :update, params: { id: import_job.id, import_job: { name: '' } }
    result = assigns(:import_job)
    assert_includes(result.errors.messages[:name],
                    I18n.t('errors.messages.blank'))
    assert_template :edit
  end

  test 'create should report error when STOMP client is not connected' do
    mock_stomp_client(UnconnectedMockStompClient.instance)

    # Verify that STOMP_CLIENT actually raises Stomp::Error::NoCurrentConnection
    assert_raises(Stomp::Error::NoCurrentConnection) do
      STOMP_CLIENT.publish(nil, nil, nil)
    end

    post :create, params: {
      import_job: { name: name, file_to_upload: fixture_file_upload('files/valid_import.csv') }
    }

    import_job = assigns(:import_job)
    assert_equal(:error, import_job.status)
  end

  test 'update should report error when STOMP client is not connected' do
    mock_stomp_client(UnconnectedMockStompClient.instance)

    # Verify that STOMP_CLIENT actually raises Stomp::Error::NoCurrentConnection
    assert_raises(Stomp::Error::NoCurrentConnection) do
      STOMP_CLIENT.publish(nil, nil, nil)
    end

    import_job = ImportJob.first
    patch :update, params: { id: import_job.id,
                             import_job: { name: import_job.name, file_to_upload: fixture_file_upload('files/valid_import.csv') } }
    result = assigns(:import_job)
    assert_equal(:error, result.status)
  end

  test 'import should report error when STOMP client is not connected' do
    mock_stomp_client(UnconnectedMockStompClient.instance)

    # Verify that STOMP_CLIENT actually raises Stomp::Error::NoCurrentConnection
    assert_raises(Stomp::Error::NoCurrentConnection) do
      STOMP_CLIENT.publish(nil, nil, nil)
    end

    import_job = ImportJob.first
    import_job.file_to_upload = fixture_file_upload('files/valid_import.csv')
    import_job.save!
    patch :import, params: { id: import_job.id }
    result = assigns(:import_job)
    assert_equal(:error, result.status)
  end
end