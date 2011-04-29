/*
 * This sample program may be used to generate test patterns.  It also
 * serves as an example of how to use the gimp-print API.
 *
 * As the purpose of this program is to allow fine grained control over
 * the output, it uses the raw CMYK output type.  This feeds 16 bits each
 * of CMYK to the driver.  This mode performs no correction on the data;
 * it passes it directly to the dither engine, performing no color,
 * density, gamma, etc. correction.  Most programs will use one of the
 * other modes (RGB, density and gamma corrected 8-bit CMYK, grayscale, or
 * black and white).
 */
 
/*

  would be better to read TIFF files directly and interleave strips from multipage files
  
    http://www.libtiff.org/libtiff.html
    https://www.ibm.com/developerworks/linux/library/l-libtiff/
    
*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
          
#include <gutenprint/gutenprint.h>

int g_channel_bit_depth = 16;
int g_raw_channels = 0;
char *g_driver = NULL;
int g_image_height = 0;
int g_image_width = 0;
char *g_page_size = NULL;

const stp_printer_t *g_printer = NULL;
stp_vars_t *g_vars = NULL;
FILE *g_input_file = NULL;
FILE *g_output_file = NULL;

static void
writefunc(void *file, const char *buf, size_t bytes)
{
  fwrite(buf, 1, bytes, (FILE *)file);
}

static stp_image_status_t
Image_get_row(stp_image_t *image, unsigned char *data, size_t byte_limit, int row)
{
  if (fread(data, 1, byte_limit, g_input_file) == byte_limit) {
    // ;;fprintf(stderr, "[Image_get_row: limit = %lu, row = %d] => STP_IMAGE_STATUS_OK\n", byte_limit, row);
    ;;fprintf(stderr, ".");
    return STP_IMAGE_STATUS_OK;
  } else {
    // ;;fprintf(stderr, "[Image_get_row: limit = %lu, row = %d] => STP_IMAGE_STATUS_ABORT\n", byte_limit, row);
    ;;fprintf(stderr, "!");
    return STP_IMAGE_STATUS_ABORT;
  }
}

static int
Image_width(stp_image_t *image)
{
  fprintf(stderr, "[Image_width => %d]\n", g_image_width);
  return g_image_width;
}

static int
Image_height(stp_image_t *image)
{
  fprintf(stderr, "[Image_height => %d]\n", g_image_height);
  return g_image_height;
}

static void
Image_init(stp_image_t *image)
{
  fprintf(stderr, "[Image_init]\n");
}

static void
Image_reset(stp_image_t *image)
{
  fprintf(stderr, "[Image_reset]\n");
}

static void
Image_conclude(stp_image_t *image)
{
  fprintf(stderr, "[Image_conclude]\n");
}

static const char *
Image_get_appname(stp_image_t *image)
{
  fprintf(stderr, "[Image_get_appname]\n");
  return "gutenprint-filter";
}

static void
show_printer_list(void)
{
  int i;

  for (i = 0; i < stp_printer_model_count(); i++) {
    const stp_printer_t *printer = stp_get_printer_by_index(i);
    printf("%s: %s\n", stp_printer_get_driver(printer), stp_printer_get_long_name(printer));
  }
}

static void
show_params(stp_vars_t *v)
{
  stp_parameter_list_t params = stp_get_parameter_list(v);
  int count = stp_parameter_list_count(params);
  int i;

  for (i = 0; i < count; i++) {
    const stp_parameter_t *p = stp_parameter_list_param(params, i);

    if (p->p_type == STP_PARAMETER_TYPE_STRING_LIST) {
      const char *val = stp_get_string_parameter(v, p->name);
      printf("%30s = %s (string)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_INT) {
      int val = stp_get_int_parameter(v, p->name);
      printf("%30s = %d (int)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_BOOLEAN) {
      int val = stp_get_boolean_parameter(v, p->name);
      printf("%30s = %s (bool)\n", p->name, val ? "true" : "false");

    } else if (p->p_type == STP_PARAMETER_TYPE_CURVE) {
      const stp_curve_t *val = stp_get_curve_parameter(v, p->name);
      printf("%30s = %p (curve)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_DOUBLE) {
      double val = stp_get_float_parameter(v, p->name);
      printf("%30s = %f (float)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_FILE) {
      const char *val = stp_get_file_parameter(v, p->name);
      printf("%30s = %s (file)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_RAW) {
      const void *val = stp_get_file_parameter(v, p->name);
      printf("%30s = %p (raw)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_DIMENSION) {
      int val = stp_get_dimension_parameter(v, p->name);
      printf("%30s = %d (dimension)\n", p->name, val);

    } else if (p->p_type == STP_PARAMETER_TYPE_ARRAY) {
      const stp_array_t *array = stp_get_array_parameter(v, p->name);
      int x_size, y_size;
      stp_array_get_size(array, &x_size, &y_size);
      printf("%30s = ??? (%dx%d array)\n", p->name, x_size, y_size);

    } else {
      printf("%30s = ??? (<%d>)\n", p->name, p->p_type);
    }
  }

  stp_parameter_list_destroy(params);
  params = NULL;
}

static void
show_channels(void)
{
  stp_parameter_t param;
  stp_describe_parameter(g_vars, "RawChannelNames", &param); 

  stp_string_list_t *channels_strlist = param.bounds.str; 
  assert(channels_strlist);
  
  int i;
  for (i = 0; i < stp_string_list_count(channels_strlist); i++) { 
    stp_param_string_t *p = stp_string_list_param(channels_strlist, i);
    printf("%s: %s\n", p->name, p->text);
  } 

  stp_parameter_description_destroy(&param); 
}

static void
show_geometry(void)
{
  int x_res, y_res;
  
  stp_describe_resolution(g_vars, &x_res, &y_res);
  printf("x_resolution: %d\n", x_res);
  printf("y_resolution: %d\n", y_res);
  
  printf("PageSize: %s\n", stp_get_string_parameter(g_vars, "PageSize"));
  printf("top: %d\n", stp_get_top(g_vars));
  printf("left: %d\n", stp_get_left(g_vars));
  printf("width: %d\n", stp_get_width(g_vars));
  printf("height: %d\n", stp_get_height(g_vars));
}

static void
init(void)
{
  char tmp[32];

  stp_init();

	g_vars = stp_vars_create();
  stp_vars_copy(g_vars, stp_default_settings());
  stp_set_driver(g_vars, g_driver); 
  g_printer = stp_get_printer(g_vars);
  assert(g_printer);
  stp_set_printer_defaults(g_vars, g_printer); 
  
  stp_set_outfunc(g_vars, writefunc);
  stp_set_errfunc(g_vars, writefunc);
  stp_set_outdata(g_vars, g_output_file);
  stp_set_errdata(g_vars, stderr);

  stp_set_string_parameter(g_vars, "InputImageType", "Raw");
  stp_set_string_parameter(g_vars, "PrintingMode", "Color");
  stp_set_string_parameter(g_vars, "ColorCorrection", "Raw");
  if (g_channel_bit_depth > 0) {
    sprintf(tmp, "%d", g_channel_bit_depth);
    stp_set_string_parameter(g_vars, "ChannelBitDepth", tmp);
  }
  if (g_raw_channels > 0) {
    sprintf(tmp, "%d", g_raw_channels);
    stp_set_string_parameter(g_vars, "RawChannels", tmp);
  }
  stp_set_string_parameter(g_vars, "Quality", "None");
  stp_set_string_parameter(g_vars, "ImageType", "None");
  stp_set_float_parameter(g_vars, "Density", 1.0);
  stp_set_string_parameter(g_vars, "DitherAlgorithm", "Adaptive");
  stp_set_boolean_parameter(g_vars, "SimpleGamma", 1);
  
  if (stp_check_string_parameter(g_vars, "PageSize", STP_PARAMETER_ACTIVE) && strcmp(stp_get_string_parameter(g_vars, "PageSize"), "Auto") == 0) {

    stp_parameter_t desc;
    stp_describe_parameter(g_vars, "PageSize", &desc);
    if (desc.p_type == STP_PARAMETER_TYPE_STRING_LIST) {
      stp_set_string_parameter(g_vars, "PageSize", desc.deflt.str);
    }
    stp_parameter_description_destroy(&desc);
    
  } else if (g_page_size) {

    stp_set_string_parameter(g_vars, "PageSize", g_page_size);
  }

  stp_set_printer_defaults_soft(g_vars, g_printer);
  
  {
    int left, right, bottom, top;

    stp_get_imageable_area(g_vars, &left, &right, &bottom, &top);

    stp_set_width(g_vars, right - left);
    stp_set_height(g_vars, bottom - top);
    stp_set_left(g_vars, left);
    stp_set_top(g_vars, top);
  }

  stp_merge_printvars(g_vars, stp_printer_get_defaults(g_printer));
  
  stp_verify(g_vars);
}

static void
print(void)
{
  static stp_image_t image = {
    Image_init,
    Image_reset,
    Image_width,
    Image_height,
    Image_get_row,
    Image_get_appname,
    Image_conclude,
    NULL
  };

  ;;fprintf(stderr, "[starting job]\n");
  stp_start_job(g_vars, &image);
  ;;fprintf(stderr, "[printing job]\n");
  stp_print(g_vars, &image);
  ;;fprintf(stderr, "[ending job]\n");
  stp_end_job(g_vars, &image);
}

static void
cleanup(void)
{
  stp_vars_destroy(g_vars);
  g_vars = NULL;
}

int
main(int argc, char **argv)
{
  int opt_show_printer_list = 0;
  int opt_show_channels = 0;
  int opt_show_params = 0;
  int opt_show_geometry = 0;
  int opt;
  
  g_input_file = stdin;
  g_output_file = stdout;
  
  while ((opt = getopt(argc, argv, "lgspP:b:c:d:w:h:o:")) != -1) {
    switch (opt) {
    case 'l':
      opt_show_printer_list = 1;
      break;
    
    case 'g':
      opt_show_geometry = 1;
      break;

    case 's':
      opt_show_channels = 1;
      break;

    case 'p':
      opt_show_params = 1;
      break;
      
    case 'P':
      g_page_size = optarg;
      break;

    case 'b':
      sscanf(optarg, "%d", &g_channel_bit_depth);
      break;

    case 'c':
      sscanf(optarg, "%d", &g_raw_channels);
      break;
      
    case 'd':
      g_driver = optarg;
      break;
      
    case 'w':
      sscanf(optarg, "%d", &g_image_width);
      break;

    case 'h':
      sscanf(optarg, "%d", &g_image_height);
      break;
      
    case 'o':
      g_output_file = fopen(optarg, "w");
      assert(g_output_file);
      break;
    
    default:
      fprintf(stderr, "Usage...\n");
      exit(1);
    }
  }
  
  argc -= optind;
  argv += optind;
  
  init();
  
  if (opt_show_printer_list) {
    show_printer_list();
    
  } else if (opt_show_channels) {
    show_channels();
    
  } else if (opt_show_params) {
    show_params(g_vars);
    
  } else if (opt_show_geometry) {
    show_geometry();
    
  } else {
    ;;fprintf(stderr, "[opening %s]\n", argv[0]);
    if (strcmp(argv[0], "-") == 0)
      print();
    else {
      g_input_file = fopen(argv[0], "r");
      assert(g_input_file);
      print();
      fclose(g_input_file);
    }
  }
 
  cleanup();
  
  return 0;
}