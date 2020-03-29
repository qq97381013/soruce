@Configuration
public class ResourceConfig implements WebMvcConfigurer {
    @Autowired
    private QrCodeProp qrCodeProp;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        String os = System.getProperty("os.name");
        if(os.toLowerCase().startsWith("win")){ //windows系统
            /** QrCode图片存储路径 */
            registry.addResourceHandler(qrCodeProp.getHttpBasePath()
                    +"/**")
                    .addResourceLocations("file:" + qrCodeProp.getStorePath() + "/");
        }else{ //linux或者mac

        }
    }

}