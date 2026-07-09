select * from  public.installation_configs
WHERE name in ('INSTALLATION_PRICING_PLAN', 'INSTALLATION_PRICING_PLAN_QUANTITY', 'INSTALLATION_IDENTIFIER');


 41 | INSTALLATION_PRICING_PLAN          | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: community\n"                            | 2025-04-26 17:23:37.286286 | 2025-04-26 17:23:37.286286 | t
 42 | INSTALLATION_PRICING_PLAN_QUANTITY | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 0\n"                                    | 2025-04-26 17:23:37.291686 | 2025-04-26 17:23:37.291686 | t
 63 | INSTALLATION_IDENTIFIER            | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 78a69abf-6eb9-47e7-8d68-d9e5922a68c0\n" | 2025-04-27 12:00:07.650157 | 2025-04-27 12:00:07.650157 | t


 CHATWOOT_HUB_URL=https://oriondesign.art.br/setup#


 
UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: enterprise\n"' 
WHERE name = 'INSTALLATION_PRICING_PLAN';

UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 10000\n"' 
WHERE name = 'INSTALLATION_PRICING_PLAN_QUANTITY';

UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: e04t63ee-5gg8-4b94-8914-ed8137a7d938\n"' 
WHERE name = 'INSTALLATION_IDENTIFIER';