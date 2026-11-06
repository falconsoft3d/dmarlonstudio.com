import { CoursesIndex } from "@/components/courses";
import { coursesUi } from "@/content/courses/ui";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("en");
export const metadata = pageMetadata("en", { title: ui.metaTitle, description: ui.intro, paths: PATHS.courses });

export default function Page() {
  return <CoursesIndex lang="en" />;
}
