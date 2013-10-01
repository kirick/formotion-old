module Formotion
  module RowType
    class ImageRow < Base
      include BW::KVO

      attr_accessor :changed

      IMAGE_VIEW_TAG=1100

      def changed?
        @changed
      end

      def build_cell(cell)
        @changed = false
        add_plus_accessory(cell)

        observe(self.row, "value") do |old_value, new_value|
          puts "change - new_value is #{new_value.class.to_s}"
          @image_view.image = new_value unless new_value.class.to_s == "String"
          #if new_value
          #  puts ""
          #  puts ""
          #  puts "Call stack for change to #{self.row.key.to_s}: #{caller.inspect.class.to_s}"
          #  puts caller.inspect
          #end
          if new_value
            self.row.row_height = 200
            cell.accessoryView = cell.editingAccessoryView = nil
          else
            self.row.row_height = 44
            add_plus_accessory(cell)
          end
          row.form.reload_data
        end
        
        @image_view = UIImageView.alloc.init
        @image_view.image = row.value if row.value
        @image_view.tag = IMAGE_VIEW_TAG
        @image_view.contentMode = UIViewContentModeScaleAspectFit
        @image_view.backgroundColor = UIColor.clearColor
        cell.addSubview(@image_view)

        cell.swizzle(:layoutSubviews) do
          def layoutSubviews
            old_layoutSubviews

            # viewWithTag is terrible, but I think it's ok to use here...
            formotion_field = self.viewWithTag(IMAGE_VIEW_TAG)

            field_frame = formotion_field.frame
            field_frame.origin.y = 10
            field_frame.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + Formotion::RowType::Base.field_buffer
            field_frame.size.width  = self.frame.size.width - field_frame.origin.x - Formotion::RowType::Base.field_buffer
            field_frame.size.height = self.frame.size.height - Formotion::RowType::Base.field_buffer
            formotion_field.frame = field_frame
          end
        end
      end

      def on_select(tableView, tableViewDelegate)
        # 12/11/12 ksi Need to check device - the default code
        # will not work on iPad
        if Device.iphone? || !Device.iphone?
          @action_sheet = UIActionSheet.alloc.init
          @action_sheet.delegate = self

          @action_sheet.destructiveButtonIndex = (@action_sheet.addButtonWithTitle "Delete") if row.value
          @action_sheet.addButtonWithTitle "Take" # if BW::Device.camera.front? or BW::Device.camera.rear?
          @action_sheet.addButtonWithTitle "Choose"
          @action_sheet.cancelButtonIndex = (@action_sheet.addButtonWithTitle "Cancel")

          @action_sheet.showInView @image_view
        else
          @image_picker = UIImagePickerController.alloc.init
          @image_picker.delegate = self

          @popover = UIPopoverController.alloc.initWithContentViewController(@image_picker)
          @popover.delegate = self
          @popover.presentPopoverFromRect(@add_button.frame, inView:@image_view, permittedArrowDirections:0, animated:true)
        end
      end

      def imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        @changed = true
        image = info.valueForKey("UIImagePickerControllerOriginalImage")
        row.value = image
        @popover.dismissPopoverAnimated(true)
      end

      def popoverControllerDidDismissPopover( popoverController )
        @popover = nil
      end

      def actionSheet actionSheet, clickedButtonAtIndex: index
        source = nil

        if index == actionSheet.destructiveButtonIndex
          @changed = true
          row.value = nil
          return
        end

        case actionSheet.buttonTitleAtIndex(index)
        when "Take"
          source = :camera
        when "Choose"
          if Device.iphone?
            source = :photo_library
          else
            @image_picker = UIImagePickerController.alloc.init
            @image_picker.delegate = self

            @popover = UIPopoverController.alloc.initWithContentViewController(@image_picker)
            @popover.delegate = self
            @popover.presentPopoverFromRect(@add_button.frame, inView:@image_view, permittedArrowDirections:0, animated:true)
          end
        when "Cancel"
        else
          p "Unrecognized button title #{actionSheet.buttonTitleAtIndex(index)}"
        end

        if source
          @camera = BW::Device.camera.send((source == :camera) ? :rear : :any)
          @camera.picture(source_type: source, media_types: [:image]) do |result|
            if result[:original_image]
              @changed = true
              row.value = result[:original_image]
            end
          end
        end
      end

      def add_plus_accessory(cell)
        @add_button ||= begin
          button = UIButton.buttonWithType(UIButtonTypeContactAdd)
          button.when(UIControlEventTouchUpInside) do
            self.on_select(nil, nil)
          end
          button
        end
        cell.accessoryView = cell.editingAccessoryView = @add_button
      end
    end
  end
end