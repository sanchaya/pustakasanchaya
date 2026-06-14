# Create a rakefile for converting PNG to ICO
namespace :icon do
  desc "Convert PNG to ICO (favicon)"
  task :convert => :environment do
    require 'chunky_png'
    
    input_file = Rails.root.join('public/assets/sanchaya-logo.png')
    output_file = Rails.root.join('public/assets/sanchaya-favicon.ico')
    
    image = ChunkyPNG::Image.from_file(input_file)
    
    # For favicon, we typically need multiple sizes
    # Create common favicon sizes
    sizes = [
      [16, 16],
      [32, 32],
      [48, 48],
      [64, 64],
      [128, 128],
      [256, 256]
    ]
    
    indexed_colors = image.resample(sizes.first[0], sizes.first[1])
    
    # Convert to indexed colors for ICO
    icon_image = indexed_colors.resample(sizes[1][0], sizes[1][1])
    
    # For now, let's use the main logo (16x16)
    icon_image = image.resample(16, 16)
    
    # Save as ICO
    icon_image.save(output_file)
    puts "Created favicon at #{output_file}"
    
    # Also copy to favicon.ico for backwards compatibility
    FileUtils.cp(output_file, Rails.root.join('public/favicon.ico'))
    puts "Copied favicon to public/favicon.ico"
  end
end
