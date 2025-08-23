ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :created_at
    column :updated_at
    actions
  end

  filter :email
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :created_at
      row :updated_at
    end
  end
end
