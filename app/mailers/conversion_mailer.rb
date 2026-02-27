class ConversionMailer < ApplicationMailer
  def result_email
    @user = params[:user]
    @conversion = params[:conversion]
    @tool_meta = ToolRegistry.find_by_class_name(@conversion.tool_name) || { name: 'File Conversion' }
    
    mail(
      to: @user.email,
      subject: "Your processed file is ready! - ConvertPro"
    )
  end
end
